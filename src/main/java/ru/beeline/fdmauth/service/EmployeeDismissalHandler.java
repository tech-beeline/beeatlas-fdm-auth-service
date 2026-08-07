package ru.beeline.fdmauth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.dto.CreateUserRequestDTO;
import ru.beeline.fdmauth.dto.CreateUserResponseDTO;
import ru.beeline.fdmauth.dto.EmployeeDismissalEventDTO;
import ru.beeline.fdmauth.dto.myprofile.MyProfileUserSearchResultDTO;
import ru.beeline.fdmauth.repository.UserProfileRepository;

import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmployeeDismissalHandler {

    private final UserProfileRepository userProfileRepository;
    private final MyProfileSearchService myProfileSearchService;
    private final UserProfileService userProfileService;

    private static final DateTimeFormatter STRICT_DATE = DateTimeFormatter.ofPattern("uuuu-MM-dd")
            .withResolverStyle(ResolverStyle.STRICT);

    public record ReassignIds(Integer currentUserId, Integer newUserId) {}

    /**
     * Сохраняет дату увольнения и создаёт/находит нового владельца.
     * Возвращает null, если событие не требует переназначения.
     */
    @Transactional(transactionManager = "transactionManager")
    public ReassignIds processAndSave(EmployeeDismissalEventDTO event) {
        if (event == null || event.getData() == null || event.getData().getId() == null) {
            return null;
        }

        Integer dismissedEmployeeNumber = event.getData().getId();
        UserProfile dismissedProfile = userProfileRepository.findByIdExt(String.valueOf(dismissedEmployeeNumber));
        if (dismissedProfile == null) {
            return null;
        }

        String dismissalDateStr = event.getData().getDateOfDismissal();
        if (dismissalDateStr != null) {
            if (dismissalDateStr.isBlank()) {
                throw new IllegalArgumentException("date_of_dismissal is blank");
            }
            try {
                log.info("date_of_dismissal is " + dismissalDateStr);
                LocalDate ld = LocalDate.parse(dismissalDateStr, STRICT_DATE);
                dismissedProfile.setDeletedDate(new Date(Date.valueOf(ld).getTime()));
                userProfileRepository.save(dismissedProfile);
            } catch (DateTimeParseException e) {
                throw new IllegalArgumentException(
                        "Invalid date_of_dismissal: '" + dismissalDateStr + "'. Expected yyyy-MM-dd", e);
            }
        }

        List<MyProfileUserSearchResultDTO> dismissedMyProfile = myProfileSearchService.search(null, dismissedEmployeeNumber);
        MyProfileUserSearchResultDTO dismissed = dismissedMyProfile != null && !dismissedMyProfile.isEmpty()
                ? dismissedMyProfile.get(0)
                : null;
        if (dismissed == null || dismissed.getId() == null) {
            throw new IllegalStateException("Dismissed employee not found in MyProfile or missing beeAtlas id");
        }

        String funcManagerEmployeeNumberStr = dismissed.getFunc_manager_employee_number();
        if (funcManagerEmployeeNumberStr == null || funcManagerEmployeeNumberStr.isBlank()) {
            throw new IllegalStateException("func_manager_employee_number is empty for dismissed employee");
        }
        Integer funcManagerEmployeeNumber = Integer.parseInt(funcManagerEmployeeNumberStr);

        List<MyProfileUserSearchResultDTO> managerMyProfile = myProfileSearchService.search(null, funcManagerEmployeeNumber);
        MyProfileUserSearchResultDTO manager = managerMyProfile != null && !managerMyProfile.isEmpty()
                ? managerMyProfile.get(0)
                : null;
        if (manager == null) {
            throw new IllegalStateException("Func manager not found in MyProfile");
        }

        // Создаём или находим запись руководителя в fdm-auth, берём ID из результата
        List<CreateUserResponseDTO> created = userProfileService.createUsers(List.of(
                CreateUserRequestDTO.builder()
                        .login(manager.getUserName())
                        .fullName(manager.getFullName())
                        .idExt(String.valueOf(funcManagerEmployeeNumber))
                        .email(manager.getEmail())
                        .build()
        ));

        Integer managerId = created != null && !created.isEmpty() ? created.get(0).getId() : null;
        if (managerId == null) {
            throw new IllegalStateException("Failed to resolve fdm-auth id for func manager after createUsers");
        }

        return new ReassignIds(dismissedProfile.getId(), managerId);
    }
}
